
WITH Recursive_Posts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.LastActivityDate,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS score_count, 
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS downvote_count  
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.PostTypeId, p.LastActivityDate
),
Recent_Activity AS (
    SELECT 
        PostId, 
        Title,
        OwnerUserId,
        (score_count - downvote_count) AS FinalScore, 
        RANK() OVER (PARTITION BY OwnerUserId ORDER BY LastActivityDate DESC) AS ActivityRank
    FROM 
        Recursive_Posts
),
User_Badges AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
Top_Users AS (
    SELECT 
        u.UserId,
        u.DisplayName, 
        u.BadgeCount,
        u.BadgeNames,
        ra.PostId,
        ra.Title,
        ra.FinalScore,
        ra.ActivityRank
    FROM 
        User_Badges u
    INNER JOIN 
        Recent_Activity ra ON u.UserId = ra.OwnerUserId
    WHERE 
        u.BadgeCount > 0 
    AND 
        ra.ActivityRank <= 5
    ORDER BY 
        ra.FinalScore DESC
)
SELECT 
    t.DisplayName AS TopUser,
    t.BadgeCount,
    t.BadgeNames,
    t.Title AS RecentPostTitle,
    t.FinalScore
FROM 
    Top_Users t
WHERE 
    t.FinalScore > 0
ORDER BY 
    t.BadgeCount DESC, t.FinalScore DESC;
