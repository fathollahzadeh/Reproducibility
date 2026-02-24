WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL 
),
PostsWithCounts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.OwnerUserId, p.PostTypeId
),
UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FrequentPostTypes AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS PostTypeFrequency
    FROM 
        Posts
    GROUP BY 
        PostTypeId
)
SELECT  
    u.UserId,
    u.DisplayName,
    u.Reputation,
    ub.BadgeCount,
    COUNT(pwc.PostId) AS TotalPosts,
    COALESCE(FPT.PostTypeFrequency, 0) AS FrequentPostTypeFrequency,
    SUM(pwc.CommentCount) AS TotalComments,
    SUM(pwc.UpVoteCount) AS TotalUpVotes,
    SUM(pwc.DownVoteCount) AS TotalDownVotes,
    CASE 
        WHEN ub.HighestBadgeClass IS NOT NULL 
        THEN 
            (CASE 
                WHEN ub.HighestBadgeClass = 1 THEN 'Gold' 
                WHEN ub.HighestBadgeClass = 2 THEN 'Silver' 
                ELSE 'Bronze' 
            END) 
        ELSE 'No Badge' 
    END AS HighestBadge
FROM 
    RankedUsers u
LEFT JOIN 
    UserBadgeCounts ub ON u.UserId = ub.UserId
LEFT JOIN 
    PostsWithCounts pwc ON u.UserId = pwc.OwnerUserId
LEFT JOIN 
    FrequentPostTypes FPT ON pwc.PostTypeId = FPT.PostTypeId
WHERE 
    u.ReputationRank < 101
GROUP BY 
    u.UserId, u.DisplayName, u.Reputation, ub.BadgeCount, ub.HighestBadgeClass, FPT.PostTypeFrequency
ORDER BY 
    u.Reputation DESC, TotalPosts DESC
LIMIT 10 OFFSET 0;