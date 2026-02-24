
WITH UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        COALESCE(SUM(p.ViewCount), 0) AS TotalPostViews,
        COALESCE(SUM(p.AnswerCount), 0) AS TotalAnswers,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        MAX(p.LastActivityDate) AS LastActivity
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title
),
CombinedStats AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        up.BadgeCount,
        up.TotalPostViews,
        up.TotalAnswers,
        pa.CommentCount,
        pa.LastActivity,
        up.TotalUpVotes,
        up.TotalDownVotes
    FROM 
        UserPerformance up
    LEFT JOIN 
        PostActivity pa ON up.UserId = pa.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    TotalPostViews,
    TotalAnswers,
    COALESCE(SUM(CommentCount), 0) AS TotalComments,
    MAX(LastActivity) AS MostRecentActivity,
    TotalUpVotes,
    TotalDownVotes
FROM 
    CombinedStats
GROUP BY 
    UserId, DisplayName, BadgeCount, TotalPostViews, TotalAnswers, TotalUpVotes, TotalDownVotes
ORDER BY 
    TotalPostViews DESC, TotalAnswers DESC, TotalUpVotes DESC
LIMIT 50;
