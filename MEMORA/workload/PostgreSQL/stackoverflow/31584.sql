
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COALESCE(SUM(ph.Depth), 0) AS PostDepthSum
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        PostHierarchy ph ON p.Id = ph.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentQuestions AS (
    SELECT 
        Id AS QuestionId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        COALESCE(ROUND(Score * 1.0 / NULLIF(ViewCount, 0), 2), 0) AS ScorePerView,
        ROW_NUMBER() OVER (ORDER BY CreationDate DESC) AS RecentRank
    FROM 
        Posts
    WHERE 
        PostTypeId = 1   
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.QuestionCount,
    ua.UpVotes,
    ua.DownVotes,
    ua.BadgeCount,
    ua.PostDepthSum,
    rq.QuestionId,
    rq.Title,
    rq.CreationDate,
    rq.ViewCount,
    rq.Score,
    rq.ScorePerView
FROM 
    UserActivity ua
LEFT JOIN 
    RecentQuestions rq ON ua.QuestionCount > 0 AND rq.RecentRank <= 5
ORDER BY 
    ua.QuestionCount DESC, 
    ua.UpVotes DESC,
    rq.ScorePerView DESC;
