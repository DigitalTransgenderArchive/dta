module ApplicationHelper

  # returns a hash with the location of the OpenSeadragon custom images
  def osd_nav_images(path_to_directory)
    {
        zoomIn: {
            REST:   path_to_image("#{path_to_directory}/zoomin_rest.png"),
            GROUP:  path_to_image("#{path_to_directory}/zoomin_grouphover.png"),
            HOVER:  path_to_image("#{path_to_directory}/zoomin_hover.png"),
            DOWN:   path_to_image("#{path_to_directory}/zoomin_pressed.png")
        },
        zoomOut: {
            REST:   path_to_image("#{path_to_directory}/zoomout_rest.png"),
            GROUP:  path_to_image("#{path_to_directory}/zoomout_grouphover.png"),
            HOVER:  path_to_image("#{path_to_directory}/zoomout_hover.png"),
            DOWN:   path_to_image("#{path_to_directory}/zoomout_pressed.png")
        },
        home: {
            REST:   path_to_image("#{path_to_directory}/home_rest.png"),
            GROUP:  path_to_image("#{path_to_directory}/home_grouphover.png"),
            HOVER:  path_to_image("#{path_to_directory}/home_hover.png"),
            DOWN:   path_to_image("#{path_to_directory}/home_pressed.png")
        },
        fullpage: {
            REST:   path_to_image("#{path_to_directory}/fullpage_rest.png"),
            GROUP:  path_to_image("#{path_to_directory}/fullpage_grouphover.png"),
            HOVER:  path_to_image("#{path_to_directory}/fullpage_hover.png"),
            DOWN:   path_to_image("#{path_to_directory}/fullpage_pressed.png")
        },
        rotateleft: {
            REST:   path_to_image("#{path_to_directory}/rotateleft_rest.png"),
            GROUP:  path_to_image("#{path_to_directory}/rotateleft_grouphover.png"),
            HOVER:  path_to_image("#{path_to_directory}/rotateleft_hover.png"),
            DOWN:   path_to_image("#{path_to_directory}/rotateleft_pressed.png")
        },
        rotateright: {
            REST:   path_to_image("#{path_to_directory}/rotateright_rest.png"),
            GROUP:  path_to_image("#{path_to_directory}/rotateright_grouphover.png"),
            HOVER:  path_to_image("#{path_to_directory}/rotateright_hover.png"),
            DOWN:   path_to_image("#{path_to_directory}/rotateright_pressed.png")
        },
        previous: {
            REST:   path_to_image("#{path_to_directory}/previous_rest.png"),
            GROUP:  path_to_image("#{path_to_directory}/previous_grouphover.png"),
            HOVER:  path_to_image("#{path_to_directory}/previous_hover.png"),
            DOWN:   path_to_image("#{path_to_directory}/previous_pressed.png")
        },
        next: {
            REST:   path_to_image("#{path_to_directory}/next_rest.png"),
            GROUP:  path_to_image("#{path_to_directory}/next_grouphover.png"),
            HOVER:  path_to_image("#{path_to_directory}/next_hover.png"),
            DOWN:   path_to_image("#{path_to_directory}/next_pressed.png")
        }
    }.to_json
  end

end
