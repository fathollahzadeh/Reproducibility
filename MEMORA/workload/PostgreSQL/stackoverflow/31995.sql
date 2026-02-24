
WITH RECURSIVE UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(p.Id) DESC) AS ActivityRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
), FilteredActivity AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        CommentCount, 
        Upvotes, 
        Downvotes
    FROM 
        UserActivity
    WHERE 
        ActivityRank <= 10
), RecentPostHistory AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.CreationDate,
        p.Title,
        p.Score,
        p.ViewCount,
        ph.PostHistoryTypeId AS HistoryType,
        LAG(ph.CreationDate) OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate) AS PreviousEditDate
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 10, 11) 
)
SELECT 
    fa.DisplayName,
    fa.PostCount,
    fa.CommentCount,
    fa.Upvotes,
    fa.Downvotes,
    COUNT(rph.PostId) AS RecentEdits,
    AVG(EXTRACT(EPOCH FROM (rph.CreationDate - rph.PreviousEditDate))) AS AvgEditInterval
FROM 
    FilteredActivity fa
LEFT JOIN 
    RecentPostHistory rph ON fa.UserId = rph.UserId
GROUP BY 
    fa.UserId, fa.DisplayName, fa.PostCount, fa.CommentCount, fa.Upvotes, fa.Downvotes
ORDER BY 
    AvgEditInterval DESC
LIMIT 10;
