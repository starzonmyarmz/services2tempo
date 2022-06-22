# Services2Tempo

A simple CLI utility written in Ruby that queries the next [Planning Center Online Service](https://www.planningcenter.com/services) you're assigned to, then exports and emails the setlist to your email. The setlist is also provided in a format that can be imported into [Tempo](http://www.frozenape.com/tempo-metronome.html).

<img width="520" alt="Terminal" src="https://user-images.githubusercontent.com/171375/175103169-e7faf879-f925-499b-b9ad-f9081f6cbb10.png">

### Setting up

1. Make a copy of `secrets.example.rb`, and rename it to `secrets.rb`.
2. In `secrets.rb` set your `userid` to your Planning Center Online user ID. To get this view your profile. In the url of this page it is the number prefaced with "AC". Do not include the "AC".
3. Create a Planning Center Online [personal user token](https://api.planningcenteronline.com/oauth/applications). In `secrets.rb` set the `token` and `secret` to your generated personal user token's _Application ID_ and _secret_.
4. In `secrets.rb` set the `email` and `password` to your email and email password. If you're using Gmail, you should use an [app-specific password](https://support.google.com/accounts/answer/185833?hl=en) (you'll need to generate this).

### Running the utility

```
> ruby ./fetch.rb
```

