WITH UserPosts AS (
    SELECT
        u.Id AS UserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TotalTagWikis,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id
),
UserVotes AS (
    SELECT
        v.UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM
        Votes v
    JOIN
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY
        v.UserId
)
SELECT
    u.Id AS UserId,
    u.DisplayName,
    up.TotalPosts,
    up.TotalQuestions,
    up.TotalAnswers,
    up.TotalTagWikis,
    up.TotalScore,
    uv.TotalVotes,
    uv.TotalUpVotes,
    uv.TotalDownVotes
FROM
    Users u
LEFT JOIN
    UserPosts up ON u.Id = up.UserId
LEFT JOIN
    UserVotes uv ON u.Id = uv.UserId
ORDER BY
    up.TotalScore DESC, uv.TotalVotes DESC
LIMIT 100;