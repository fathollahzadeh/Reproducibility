
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank,
        p.OwnerUserId
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    WHERE
        p.CreationDate >= (CAST('2024-10-01' AS DATE) - INTERVAL '1 year')
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, p.AcceptedAnswerId, p.OwnerUserId
),
RecentAcceptedAnswers AS (
    SELECT
        AcceptedAnswerId AS PostId,
        COUNT(*) AS AcceptedAnswerCount
    FROM
        Posts
    WHERE
        PostTypeId = 2
        AND EXISTS (
            SELECT 1 
            FROM Posts p 
            WHERE p.Id = Posts.AcceptedAnswerId 
            AND p.Score > 0
        )
    GROUP BY
        AcceptedAnswerId
),
UserEngagement AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges
    FROM
        Users u
    LEFT JOIN
        Votes v ON u.Id = v.UserId
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName
)
SELECT 
    r.OwnerUserId,
    COALESCE(ue.DisplayName, 'Unknown User') AS UserName,
    SUM(r.Score) AS TotalScore,
    COUNT(r.PostId) AS TotalPosts,
    SUM(COALESCE(raa.AcceptedAnswerCount, 0)) AS TotalAcceptedAnswers,
    MAX(r.RecentPostRank) AS MaxRecentPostRank,
    STRING_AGG(DISTINCT pht.Name, ', ') AS PostHistoryTypesChanged
FROM 
    RankedPosts r
LEFT JOIN 
    RecentAcceptedAnswers raa ON r.PostId = raa.PostId
LEFT JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    PostHistory ph ON r.PostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
LEFT JOIN 
    UserEngagement ue ON u.Id = ue.UserId
WHERE 
    (r.RecentPostRank <= 3 AND r.CommentCount > 5) OR 
    (r.CommentCount > 10 AND r.Score > 0)
GROUP BY 
    r.OwnerUserId, ue.DisplayName
HAVING 
    SUM(r.Score) > 50
ORDER BY 
    TotalScore DESC, UserName
LIMIT 10;
