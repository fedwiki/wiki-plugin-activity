module.exports = function (grunt) {
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-mocha-test');

  grunt.initConfig({

    authors: {
      prior: [
        "Ward Cunningham <ward@c2.com>",
        "Nick Niemeir <nick.niemeir@gmail.com>",
        "Marcin Cieslak <saper@saper.info>"
      ]
    },

    coffee: {
      client: {
        expand: true,
        options: {
          sourceMap: true
        },
        src: ['client/*.coffee', 'test/*.coffee'],
        ext: '.js'
      }
    },

    mochaTest: {
      test: {
        options: {
          reporter: 'spec'
        },
        src: ['test/**/*.js']
      }
    },


    watch: {
      all: {
        files: ['client/*.coffee', 'test/*.coffee'],
        tasks: ['coffee','mochaTest']
      }
    }
  });

  grunt.registerTask( "update-authors", function () {
    var getAuthors = require("grunt-git-authors"),
    done = this.async();

    getAuthors({
      priorAuthors: grunt.config( "authors.prior")
      }, function(error, authors) {
        if (error) {
          grunt.log.error(error);
          return done(false);
        }

        grunt.file.write("AUTHORS.txt",
          "Authors ordered by first contribution\n\n" +
          authors.join("\n") + "\n");
      });
  });

  grunt.registerTask('build', ['coffee', 'mochaTest']);
  grunt.registerTask('default', ['build']);

};
