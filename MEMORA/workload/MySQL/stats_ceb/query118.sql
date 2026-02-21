SELECT
    COUNT(*)
FROM
    postHistory as ph,
    posts as p,
    votes as v,
    users as u
WHERE
    u.Id = p.OwnerUserId
    AND p.Id = ph.PostId
    AND p.Id = v.PostId
    AND ph.CreationDate <= '2014-07-28 13:25:35'
    AND p.PostTypeId = 1
    AND p.AnswerCount >= 0
    AND p.AnswerCount <= 4
    AND v.CreationDate >= '2010-07-20 00:00:00'
    AND v.CreationDate <= '2014-09-03 00:00:00'
    AND u.DownVotes = 0
    AND u.CreationDate <= '2014-08-08 07:03:29';