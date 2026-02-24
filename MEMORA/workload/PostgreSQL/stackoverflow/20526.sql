
WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank,
        AVG(v.BountyAmount) FILTER(WHERE v.VoteTypeId IN (8, 9)) OVER (PARTITION BY u.Id) AS AvgBounty
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE u.Reputation > 1000
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        COALESCE(p.ViewCount, 0) AS TotalViews,
        COALESCE(p.AnswerCount, 0) AS TotalAnswers,
        COALESCE(p.CommentCount, 0) AS TotalComments,
        MAX(ph.CreationDate) AS LastEdited,
        COUNT(DISTINCT ph.Id) FILTER (WHERE ph.PostHistoryTypeId IN (4, 5, 6)) AS EditCount
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.OwnerUserId, p.PostTypeId
),
PostWithMetrics AS (
    SELECT 
        pm.PostId,
        pm.OwnerUserId,
        pm.TotalViews,
        pm.TotalAnswers,
        pm.TotalComments,
        pm.LastEdited,
        pm.EditCount,
        um.UserRank,
        um.Reputation,
        um.AvgBounty
    FROM PostMetrics pm
    JOIN UserMetrics um ON pm.OwnerUserId = um.UserId
)
SELECT 
    pwm.PostId,
    pwm.OwnerUserId,
    pwm.TotalViews,
    pwm.TotalAnswers,
    pwm.TotalComments,
    pwm.LastEdited,
    pwm.EditCount,
    pwm.UserRank,
    pwm.Reputation,
    pwm.AvgBounty,
    CASE 
        WHEN pwm.TotalAnswers > 0 THEN pwm.TotalAnswers * 1.0 / NULLIF(pwm.TotalViews, 0) 
        ELSE 0 
    END AS AnswerToViewRatio,
    CASE 
        WHEN pwm.EditCount > 0 THEN pwm.TotalComments / NULLIF(pwm.EditCount, 0) 
        ELSE NULL 
    END AS CommentToEditRatio
FROM PostWithMetrics pwm
WHERE pwm.UserRank <= 100
ORDER BY pwm.TotalViews DESC, pwm.Reputation DESC
LIMIT 50;
