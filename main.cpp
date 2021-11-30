#include <iostream>
#include <cmath>
#include "SFML/Graphics.hpp"

int main()
{
    int w = 1080;
    int h = 720;

    int mouseX = w / 2;
    int mouseY = h / 2;
    float mouseSensitivity = 1.0f;
    bool mouseVisible = true;


    sf::Vector3f pos = sf::Vector3f(-5.0f, 0.0f, 0.0f);
    sf::Vector3f viewDir = sf::Vector3f(1, 0, 0);

    sf::RenderWindow window(sf::VideoMode(w, h), "Ray tracing", sf::Style::Titlebar | sf::Style::Close);
    window.setFramerateLimit(60);
    window.setMouseCursorVisible(mouseVisible);

    sf::RenderTexture texture;
    texture.create(w, h);
    sf::Sprite sprite = sf::Sprite(texture.getTexture());

    sf::Shader shader;
    shader.loadFromFile("shader.glsl", sf::Shader::Fragment);
    shader.setUniform("u_resolution", sf::Vector2f(w, h));

    while (window.isOpen())
    {
        // check all the window's events that were triggered since the last iteration of the loop
        sf::Event event;
        while (window.pollEvent(event))
        {
            // "close requested" event: we close the window
            if (event.type == sf::Event::Closed || event.type == sf::Event::KeyPressed && event.key.code == sf::Keyboard::Escape) {
                window.close();
            } else if (event.type == sf::Event::MouseMoved) {
                mouseX = event.mouseMove.x;
                mouseY = event.mouseMove.y;
            } else if (event.type == sf::Event::KeyPressed) {
                if (event.key.code == sf::Keyboard::W);
//                if (event.key.code == sf::Keyboard::A) wasdUD[1] = true;
//                if (event.key.code == sf::Keyboard::S) wasdUD[2] = true;
//                if (event.key.code == sf::Keyboard::D) wasdUD[3] = true;
//                if (event.key.code == sf::Keyboard::Space) wasdUD[4] = true;
//                if (event.key.code == sf::Keyboard::LShift) wasdUD[5] = true;
            }
        }

        // clear the window with black color
        window.clear(sf::Color::Black);


        std::cout << mouseX << ' ' << mouseY << '\n';
        shader.setUniform("u_mouse", sf::Vector2f(mouseX, mouseY));

        // draw everything here...
        window.draw(sprite, &shader);

        // end the current frame
        window.display();
    }
    return 0;
}
