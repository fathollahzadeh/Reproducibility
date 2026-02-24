
WITH PostStats AS (
    SELECT
        p.Id AS PostId,
        p.OwnerUserId,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        (SELECT COUNT(*) FROM Votes v2 WHERE v2.PostId = p.Id AND v2.VoteTypeId IN (10, 11, 12)) AS CloseReopenCounts,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserRecentPostRank
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        p.Id, p.OwnerUserId, p.AcceptedAnswerId
),
RankedUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(b.Name, 'No Badge') AS BadgeName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        COUNT(DISTINCT ps.PostId) AS TotalPosts,
        MAX(ps.CommentCount) AS MaxCommentsOnSinglePost
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    LEFT JOIN
        PostStats ps ON u.Id = ps.OwnerUserId
    GROUP BY
        u.Id, u.DisplayName, u.Reputation, b.Name
    HAVING
        COUNT(DISTINCT ps.PostId) > 0
    ORDER BY
        u.Reputation DESC
)
SELECT
    r.UserId,
    r.DisplayName,
    r.Reputation,
    r.BadgeName,
    r.GoldBadgeCount,
    r.SilverBadgeCount,
    r.TotalPosts,
    r.MaxCommentsOnSinglePost,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Tags t 
     WHERE t.ExcerptPostId IN (SELECT p.Id 
                                FROM Posts p 
                                WHERE p.OwnerUserId = r.UserId) 
     AND t.Count > 10) AS MostUsedTags,
    CASE 
        WHEN (SELECT MAX(UserRecentPostRank) FROM PostStats ps2 WHERE ps2.OwnerUserId = r.UserId) > 1 THEN 'Frequent Poster'
        ELSE 'Occasional Poster'
    END AS PostingFrequency
FROM
    RankedUsers r
LEFT JOIN 
    PostStats ps ON r.UserId = ps.OwnerUserId
WHERE 
    r.Reputation > 1000
    AND (r.MaxCommentsOnSinglePost IS NULL OR r.MaxCommentsOnSinglePost > 5)
ORDER BY 
    r.Reputation DESC, r.TotalPosts DESC
LIMIT 10 OFFSET 0;
