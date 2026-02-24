WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        p.Score,
        p.AnswerCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM
        Posts p
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserAverages AS (
    SELECT
        u.Id AS UserId,
        AVG(u.Reputation) AS AvgReputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
TopRankedPosts AS (
    SELECT
        rp.Id,
        rp.Title,
        rp.Score,
        rp.OwnerUserId,
        COALESCE(ua.AvgReputation, 0) AS OwnerAverageReputation
    FROM
        RankedPosts rp
    LEFT JOIN
        UserAverages ua ON rp.OwnerUserId = ua.UserId
    WHERE
        rp.Rank <= 5
),
PostCommentStats AS (
    SELECT
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN c.Score > 0 THEN 1 ELSE 0 END) AS PositiveComments,
        SUM(CASE WHEN c.Score < 0 THEN 1 ELSE 0 END) AS NegativeComments
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    GROUP BY
        p.Id
)
SELECT
    trp.Title AS TopPostTitle,
    trp.Score AS TopPostScore,
    pc.CommentCount AS TotalComments,
    pc.PositiveComments AS PositiveCommentCount,
    pc.NegativeComments AS NegativeCommentCount,
    CASE
        WHEN trp.OwnerAverageReputation IS NULL THEN 'Unknown'
        WHEN trp.OwnerAverageReputation > 1000 THEN 'Elite'
        ELSE 'Novice'
    END AS OwnerReputationCategory
FROM
    TopRankedPosts trp
JOIN
    PostCommentStats pc ON trp.Id = pc.PostId
WHERE
    EXISTS (
        SELECT 1
        FROM Votes v
        WHERE v.PostId = trp.Id
        AND v.VoteTypeId = 2 
        HAVING COUNT(v.Id) > 5
    )
ORDER BY
    trp.Score DESC,
    pc.CommentCount DESC;