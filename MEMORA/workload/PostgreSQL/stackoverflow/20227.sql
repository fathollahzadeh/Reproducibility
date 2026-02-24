
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN vt.Id = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN vt.Id = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM
        Posts p
    LEFT JOIN
        Votes vt ON p.Id = vt.PostId
    WHERE
        p.PostTypeId = 1 AND p.Score > 0
),
UserStatistics AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePostCount,
        AVG(p.Score) AS AverageScore
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        PositivePostCount,
        AverageScore,
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM
        UserStatistics
    WHERE
        Reputation > 1000
),
CommentsSum AS (
    SELECT
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    GROUP BY
        p.Id
)

SELECT
    tp.UserId,
    tp.DisplayName,
    tp.Reputation,
    tp.PostCount,
    tp.PositivePostCount,
    tp.AverageScore,
    COALESCE(ps.UpVotes, 0) AS TotalUpVotes,
    COALESCE(ps.DownVotes, 0) AS TotalDownVotes,
    COALESCE(cs.CommentCount, 0) AS TotalComments,
    COUNT(DISTINCT l.RelatedPostId) AS RelatedPostsCount
FROM
    TopUsers tp
LEFT JOIN
    RankedPosts ps ON tp.UserId = ps.PostId
LEFT JOIN
    CommentsSum cs ON ps.PostId = cs.PostId
LEFT JOIN
    PostLinks l ON ps.PostId = l.PostId
WHERE
    (tp.PostCount > 5 OR tp.PositivePostCount > 2)
    AND (tp.AverageScore IS NOT NULL OR tp.Reputation > 1500)
    AND EXISTS (
        SELECT
            1
        FROM
            Badges b
        WHERE
            b.UserId = tp.UserId AND b.Class = 1
    )
GROUP BY
    tp.UserId, tp.DisplayName, tp.Reputation, tp.PostCount,
    tp.PositivePostCount, tp.AverageScore, ps.UpVotes, ps.DownVotes, cs.CommentCount, tp.Rank
ORDER BY
    tp.Rank;
