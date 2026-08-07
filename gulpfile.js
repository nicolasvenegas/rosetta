const gulp         = require('gulp');
const sass         = require('gulp-sass')(require('sass-embedded'));
const browserSync  = require('browser-sync').create();
const sourcemaps   = require('gulp-sourcemaps');
const { exec }     = require('child_process');
const fs           = require('fs');
const ghPages      = require('gh-pages');

const includePaths = [
    'node_modules/foundation-sites/scss',
    'node_modules/motion-ui/src'
];

function clean(done) {
    if (fs.existsSync('dist')) {
        fs.rmSync('dist', { recursive: true, force: true });
    }
    done();
}

function sassBuild() {
    return gulp.src(['scss/app.scss'])
        .pipe(sourcemaps.init())
        .pipe(sass({
            includePaths: includePaths,
            outputStyle: 'compressed',
            quietDeps: true, 
            silenceDeprecations: ['import', 'legacy-js-api', 'if-function']
        }).on('error', sass.logError))
        .pipe(sourcemaps.write('.'))
        .pipe(gulp.dest('dist/css'))
        .pipe(browserSync.stream());
}

function copyAssets() {
    gulp.src('img/**/*', { allowEmpty: true }).pipe(gulp.dest('dist/img'));
    return gulp.src([
        'js/**/*.js',
        'node_modules/jquery/dist/jquery.min.js',
        'node_modules/foundation-sites/dist/js/foundation.min.js',
        'node_modules/what-input/dist/what-input.min.js'
    ], { allowEmpty: true }).pipe(gulp.dest('dist/js'));
}

function buildPandoc(done) {
    exec('bash build.sh', (err, stdout, stderr) => {
        if (stdout) console.log(stdout);
        if (stderr) console.error(stderr);
        done(err);
    });
}

function deploy(done) {
    ghPages.publish('dist', {
        branch: 'gh-pages',
        message: 'Auto-generated update ' + new Date().toISOString()
    }, (err) => {
        if (err) console.error("Error en Deploy:", err);
        done(err);
    });
}

function serve() {
    browserSync.init({
        server: { baseDir: "./dist", index: "index.html" },
        notify: false
    });

    gulp.watch("scss/**/*.scss", gulp.series(sassBuild, deploy));
    
    gulp.watch(
        ["content/**/*.md", "layout.html", "layout-archivo.html"], 
        gulp.series(buildPandoc, copyAssets, deploy, (done) => {
            browserSync.reload();
            done();
        })
    );
}

gulp.task('default', gulp.series(clean, copyAssets, buildPandoc, sassBuild, serve));
gulp.task('deploy', gulp.series(clean, copyAssets, buildPandoc, sassBuild, deploy));
