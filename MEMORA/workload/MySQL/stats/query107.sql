SELECT
    COUNT(*)
FROM
    comments as c,
    votes as v,
    badges as b,
    users as u
WHERE
    u.Id = b.UserId
    AND u.Id = c.UserId
    AND u.Id = v.UserId
    AND c.Score = 1
    AND c.CreationDate >= '2010-08-27 14:12:07'
    AND v.VoteTypeId = 5
    AND v.CreationDate >= '2010-07-19 00:00:00'
    AND v.CreationDate <= '2014-09-13 00:00:00'
    AND b.Date <= '2014-08-19 10:32:13'
    AND u.Reputation >= 1;