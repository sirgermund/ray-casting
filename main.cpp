#include <iostream>
#include <cmath>
#include "SFML/Graphics.hpp"

sf::Vector3f rotY(sf::Vector3f &dir, float angle) {
    sf::Vector3f res;
    float cos = std::cos(angle);
    float sin = std::sin(angle);
    res.x = dir.x * cos + dir.z * sin;
    res.y = dir.y;
    res.z = -dir.x * sin + dir.z  * cos;
    return res;
}

sf::Vector3f rotZ(sf::Vector3f &dir, float angle) {
    sf::Vector3f res;
    float cos = std::cos(angle);
    float sin = std::sin(angle);
    res.x = dir.x * cos - dir.y * sin;
    res.y = dir.x * sin + dir.y * cos;
    res.z = dir.z;
    return res;
}

int main() {
    float DOUBLE_PI = 2 * M_PI;

    int w = 1920;
    int h = 1080;

    int mouseX = w / 2;
    int mouseY = h / 2;
    float mx = 0;
    float my = 0;
    float mouseSensitivity = 1.0f;
    bool mouseVisible = false;

    float speed = 0.1;


    sf::Vector3f pos = sf::Vector3f(-5.0f, 0.0f, 0.0f);

    sf::RenderWindow window(sf::VideoMode(w, h), "Ray tracing", sf::Style::Titlebar | sf::Style::Close);
    window.setFramerateLimit(60);
    window.setMouseCursorVisible(mouseVisible);
//    sf::Mouse::setPosition(sf::Vector2i(w / 2, h / 2), window);

    sf::RenderTexture texture;
    texture.create(w, h);
    sf::Sprite sprite = sf::Sprite(texture.getTexture());

    sf::Shader shader;
    shader.loadFromFile("shader.glsl", sf::Shader::Fragment);
    shader.setUniform("u_resolution", sf::Vector2f(w, h));

    // text
    sf::Font font;
    if (!font.loadFromFile("arial.ttf"))
    {
        return 1;
    }

    sf::Text text;

    // select the font
    text.setFont(font); // font is a sf::Font

    // set the character size
    text.setCharacterSize(24); // in pixels, not points!

    // set the color
    text.setFillColor(sf::Color::White);

    // set the text style
    text.setStyle(sf::Text::Bold);

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
                mouseX += event.mouseMove.x - w / 2;
                mouseY += event.mouseMove.y - h / 2;
                sf::Mouse::setPosition(sf::Vector2i(w / 2, h / 2), window);
                mx = ((float)mouseX / w - 0.5f) * mouseSensitivity;
                my = -((float)mouseY / h - 0.5f) * mouseSensitivity;

                mx -= DOUBLE_PI * ((int)(mx / DOUBLE_PI));
                my -= DOUBLE_PI * ((int)(my / DOUBLE_PI));
                my = fmin(M_PI/2, fmax(-M_PI/2, my));

            } else if (event.type == sf::Event::KeyPressed) {
                sf::Vector3f flyDir = sf::Vector3f(0, 0, 0);

                if (event.key.code == sf::Keyboard::Num0)
                    speed += 0.1;
                else if (event.key.code == sf::Keyboard::Num9)
                    speed -= 0.1;

                // вперед / назад
                if (event.key.code == sf::Keyboard::W)
                    flyDir = sf::Vector3f(1, 0, 0);
                else if (event.key.code == sf::Keyboard::S)
                    flyDir = sf::Vector3f(-1, 0, 0);

                 // влево / вправо
                if (event.key.code == sf::Keyboard::A)
                    flyDir = sf::Vector3f(0, -1, 0);
                else if (event.key.code == sf::Keyboard::D)
                    flyDir = sf::Vector3f(0, 1, 0);

                // вверх / вниз
                if (event.key.code == sf::Keyboard::Space)
                    pos.z -= speed;
                else if (event.key.code == sf::Keyboard::LControl)
                    pos.z += speed;

                flyDir = rotY(flyDir, my);
                flyDir = rotZ(flyDir, mx);

                pos += flyDir * speed;
            }
        }

        // clear the window with black color
        window.clear(sf::Color::Black);

        // set the string to display
        text.setString("pos: x " + std::to_string(pos.x) + " y " + std::to_string(pos.y) + " z " + std::to_string(pos.z) + '\n' + "speed: " + std::to_string(speed));

        shader.setUniform("u_mouse", sf::Vector2f(mx, my));
        shader.setUniform("u_pos", pos);

        // draw everything here...
        window.draw(sprite, &shader);
        window.draw(text);

        // end the current frame
        window.display();
    }
    return 0;
}
