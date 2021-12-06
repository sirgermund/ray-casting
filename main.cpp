#include <iostream>
#include <cmath>
#include <random>
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

    int framesStill = 1;

    std::random_device rd;
    std::mt19937 e2(rd());
    std::uniform_real_distribution<> dist(0.0f, 1.0f);

    sf::Vector3f pos = sf::Vector3f(-5.0f, 0.0f, 0.0f);

    sf::RenderWindow window(sf::VideoMode(w, h), "Ray tracing", sf::Style::Titlebar | sf::Style::Close | sf::Style::Fullscreen);
    window.setFramerateLimit(60);
    window.setMouseCursorVisible(mouseVisible);
//    sf::Mouse::setPosition(sf::Vector2i(w / 2, h / 2), window);
    std::cout << "Using OpenGL " << window.getSettings().majorVersion << "." << window.getSettings().minorVersion << std::endl;

    sf::RenderTexture firstTexture;
    firstTexture.create(w, h);
    sf::Sprite firstTextureSprite = sf::Sprite(firstTexture.getTexture());
    sf::Sprite firstTextureSpriteFlipped = sf::Sprite(firstTexture.getTexture());
    firstTextureSpriteFlipped.setScale(1, -1);
    firstTextureSpriteFlipped.setPosition(0, h);

    sf::RenderTexture outputTexture;
    outputTexture.create(w, h);
    sf::Sprite outputTextureSprite = sf::Sprite(outputTexture.getTexture());
    sf::Sprite outputTextureSpriteFlipped = sf::Sprite(firstTexture.getTexture());
    outputTextureSpriteFlipped.setScale(1, -1);
    outputTextureSpriteFlipped.setPosition(0, h);

    sf::Shader shader;
    shader.loadFromFile("new_shader.glsl", sf::Shader::Fragment);
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
                float xMove = event.mouseMove.x - w / 2;
                float yMove = event.mouseMove.y - h / 2;
                mouseX += xMove;
                mouseY += yMove;
                sf::Mouse::setPosition(sf::Vector2i(w / 2, h / 2), window);
                mx = ((float)mouseX / w - 0.5f) * mouseSensitivity;
                my = -((float)mouseY / h - 0.5f) * mouseSensitivity;

                mx -= DOUBLE_PI * ((int)(mx / DOUBLE_PI));
                my -= DOUBLE_PI * ((int)(my / DOUBLE_PI));
                my = fmin(M_PI/2, fmax(-M_PI/2, my));

                if (xMove != 0 || yMove != 0) framesStill = 1;

            } else if (event.type == sf::Event::KeyPressed) {
                std::cout << "Key Pressed\n";
                framesStill = 1;
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
        shader.setUniform("u_seed1", sf::Vector2f((float)dist(e2), (float)dist(e2)) * 999.0f);
        shader.setUniform("u_seed2", sf::Vector2f((float)dist(e2), (float)dist(e2)) * 999.0f);
        shader.setUniform("u_sample_part", 1.0f / framesStill);

        // draw everything here...
        if (framesStill % 2 == 1)
        {
//            std::cout << "Texture 1\n";
            shader.setUniform("u_sample", firstTexture.getTexture());
            outputTexture.draw(firstTextureSpriteFlipped, &shader);
            window.draw(outputTextureSprite);
        }
        else
        {
//            std::cout << "Texture 2\n";
            shader.setUniform("u_sample", outputTexture.getTexture());
            firstTexture.draw(outputTextureSpriteFlipped, &shader);
            window.draw(firstTextureSprite);
        }
        window.draw(text);

        // end the current frame
        window.display();
        framesStill++;
    }
    return 0;
}
