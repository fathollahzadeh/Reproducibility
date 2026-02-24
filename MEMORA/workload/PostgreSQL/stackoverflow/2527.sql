WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), -1) AS AcceptedAnswer
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserVotes AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        SUM(CASE WHEN v.VoteTypeId = 6 THEN 1 ELSE 0 END) AS CloseVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
PostsWithBadges AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(b.Class, 0) AS BadgeClass
    FROM 
        Posts p
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId 
    WHERE 
        b.Date = (SELECT MAX(Date) FROM Badges WHERE UserId = p.OwnerUserId)
),
FinalResults AS (
    SELECT 
        rp.Title,
        rp.Score,
        rp.ViewCount,
        COALESCE(uv.Upvotes, 0) AS Upvotes,
        COALESCE(uv.Downvotes, 0) AS Downvotes,
        pwb.BadgeClass,
        CASE 
            WHEN rp.UserRank = 1 THEN 'Top'
            WHEN rp.UserRank <= 5 THEN 'High'
            ELSE 'Low'
        END AS EngagementLevel
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserVotes uv ON rp.OwnerUserId = uv.UserId
    LEFT JOIN 
        PostsWithBadges pwb ON rp.Id = pwb.PostId
    WHERE 
        rp.ViewCount > 100 AND 
        rp.AcceptedAnswer != -1 
)
SELECT 
    COUNT(*) AS TotalPosts,
    AVG(Score) AS AverageScore,
    MAX(ViewCount) AS MaxViewCount,
    MIN(BadgeClass) AS MinimumBadgeClass,
    SUM(CASE WHEN EngagementLevel = 'Top' THEN 1 ELSE 0 END) AS TopEngagementCount
FROM 
    FinalResults
WHERE 
    BadgeClass > 0
GROUP BY 
    EngagementLevel
ORDER BY 
    EngagementLevel DESC;