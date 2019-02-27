---
title: "`gcloud kms encrypt` and newlines"
date: 2019-02-26T20:18:14-05:00
slug: gcloud-kms-encrypt-and-newlines
tags:
  - Google Cloud
  - secrets
  - CI
---

One way to encrypt a secret to use with Google Cloud's [KMS product](https://cloud.google.com/kms/) is to use the [`gcloud` command-line tool](https://cloud.google.com/sdk/gcloud/), with the `gcloud kms encrypt` command. It has a slightly sharp edge that both myself and a colleague recently (and independently) cut ourselves on, hence this post.

`gcloud kms encrypt` usage is straightforward enough and pretty [well-documented](https://cloud.google.com/kms/docs/encrypt-decrypt). Currently it manages input and output only by files. You pass it a file containing your plaintext secret using the `--plaintext-file` flag, and it will write the encrypted version out to the path given by the `--ciphertext-file` flag.

This is fine, but it is fairly easy to inadvertently include a trailing newline in the file containing the plaintext secret, and if this happens, your secret will include that newline as part of the text. We noticed this when we printed one out in our logs and it contained a `\n` at the end.

Why might this happen? For example, using `echo` like this:

```
echo "thesecret" > secret.txt
```

...will include a newline, so use `echo -n` to avoid that. Another possibility could be that you are using an editor which is either automatically saving your text files with trailing newlines when they are missing, or warning you that you should on any files missing them.

Either way, you will want to always make sure that if you are using `gcloud kms encrypt`, that your source plaintext file contains only exactly the characters you want encrypted.
