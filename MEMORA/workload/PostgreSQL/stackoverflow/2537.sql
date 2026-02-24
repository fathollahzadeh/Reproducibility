WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND  
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.UpVotes,
        u.DownVotes,
        (u.UpVotes - u.DownVotes) AS NetVotes,
        COUNT(DISTINCT p.Id) AS QuestionsAsked
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  
    GROUP BY 
        u.Id, u.DisplayName, u.UpVotes, u.DownVotes
),
BadgeStats AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass  
    FROM 
        Badges b
    WHERE 
        b.Date >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        b.UserId
)
SELECT 
    ua.DisplayName,
    ua.NetVotes,
    ua.QuestionsAsked,
    COALESCE(bs.BadgeCount, 0) AS BadgeCount,
    COALESCE(bs.HighestBadgeClass, 0) AS HighestBadgeClass,
    rp.Title,
    rp.Score,
    rp.CreationDate
FROM 
    UserActivity ua
LEFT JOIN 
    BadgeStats bs ON ua.UserId = bs.UserId
LEFT JOIN 
    RankedPosts rp ON ua.UserId = rp.PostId  
WHERE 
    ua.NetVotes >= 0  
ORDER BY 
    ua.NetVotes DESC,
    ua.QuestionsAsked DESC,
    rp.Score DESC;