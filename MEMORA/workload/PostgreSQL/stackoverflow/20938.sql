
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 1) AS TotalQuestions,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 2) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
QuestionData AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalComments,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS TotalCloseVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount
),
TopQuestions AS (
    SELECT 
        q.*,
        DENSE_RANK() OVER (ORDER BY q.ViewCount DESC) AS RankByViews
    FROM 
        QuestionData q
),
RecentActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS RecentPosts,
        SUM(v.BountyAmount) AS RecentBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
    WHERE 
        u.CreationDate < CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalBounty,
    us.TotalBadges,
    tq.Title AS TopQuestionTitle,
    tq.ViewCount AS TopQuestionViews,
    ra.RecentPosts,
    ra.RecentBounties
FROM 
    UserStats us
LEFT JOIN 
    TopQuestions tq ON us.TotalQuestions > 0 AND tq.RankByViews <= 5 
LEFT JOIN 
    RecentActivity ra ON us.UserId = ra.UserId
WHERE 
    us.Reputation >= 1000
ORDER BY 
    us.Reputation DESC,
    tq.ViewCount DESC NULLS LAST;
