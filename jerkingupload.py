import re
import requests
import sys
from bs4 import BeautifulSoup as bs

regex_url = re.compile(
    r'^(?:http)s?://'  # http:// or https://
    r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+(?:[A-Z]{2,6}\.?|[A-Z0-9-]{2,}\.?)|'  # domain...
    r'localhost|'  # localhost...
    r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'  # ...or ip
    r'(?::\d+)?'  # optional port
    r'(?:/?|[/?]\S+)$', re.IGNORECASE)


def upload_url_to_jerk(url, only_url=True):
    session = requests.session()
    resp = session.post(
        'https://jerking.empornium.ph/json',
        data={
            'source': url,
            'action': 'upload',
            'privacy': 'public',
            'type': 'url',
            'auth_token': bs(
                session.get('https://jerking.empornium.ph/').content,
                'html.parser'
            ).find("input", attrs={'name': 'auth_token'}).get('value'),
        }
    ).json()
    if resp['status_code'] != 200 :
        print(resp)
        raise Exception('Sommething go wrong !')
    if not only_url:
        return {
            "url_viewer": resp['image']['url_viewer'],
            "url": resp['image']['url'],
            "medium": resp['image']['medium']['url'],
            "thumb": resp['image']['thumb']['url'],
        }
    return resp['image']['url']


def upload_file_to_jerk(file_path, only_url=True):
    session = requests.session()
    with open(file_path, "rb") as f:
        resp = session.post(
            'https://jerking.empornium.ph/json',
            files={'source': f},
            data={
                'action': 'upload',
                'privacy': 'public',
                'type': 'file',
                'auth_token': bs(
                    session.get('https://jerking.empornium.ph/').content,
                    'html.parser'
                ).find("input", attrs={'name': 'auth_token'}).get('value'),
            }
        ).json()
    if resp['status_code'] != 200:
        print(resp)
        raise Exception('Sommething go wrong !')
    if not only_url:
        return {
            "url_viewer": resp['image']['url_viewer'],
            "url": resp['image']['url'],
            "medium": resp['image']['medium']['url'],
            "thumb": resp['image']['thumb']['url'],
        }
    return resp['image']['url']


def upload_to_jerk(url_or_path, only_url=True):
    return upload_url_to_jerk(url_or_path, only_url) if regex_url.match(url_or_path) else upload_file_to_jerk(url_or_path,
                                                                                                       only_url)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit('Usage: %s <url or path file to upload>'.format(sys.argv[0]))
    print(upload_to_jerk(sys.argv[1], only_url=True))
