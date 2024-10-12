module.exports = function (grunt) {
  grunt.loadNpmTasks('grunt-browserify');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-mocha-test');
  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-git-authors');

  grunt.initConfig({

    authors: {
      prior: [
        "Ward Cunningham <ward@c2.com>",
        "Nick Niemeir <nick.niemeir@gmail.com>",
        "Marcin Cieslak <saper@saper.info>"
      ]
    },

    // tidy-up before we start the build
    clean: ['test/test.js', 'test/test.js.map'],

    mochaTest: {
      test: {
        options: {
          reporter: 'spec',
          require: 'coffeescript/register'
        },
        src: ['test/test.coffee']
      }
    },

    watch: {
      all: {
        files: ['client/*.coffee', 'test/*.coffee'],
        tasks: ['build']
      }
    }
  });

  grunt.registerTask('build', ['clean', 'mochaTest', 'browserify']);
  grunt.registerTask('default', ['build']);

};
