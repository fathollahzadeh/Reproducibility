
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.CreationDate,
        a.PostTypeId,
        a.ParentId,
        h.Level + 1 AS Level
    FROM 
        Posts AS a
    JOIN 
        PostHierarchy h ON a.ParentId = h.PostId
    WHERE 
        a.PostTypeId = 2 
)

SELECT 
    u.DisplayName,
    u.Reputation,
    p.Title AS QuestionTitle,
    COUNT(c.Id) AS CommentCount,
    AVG(v.BountyAmount) AS AverageBounty,
    MAX(CASE WHEN bh.Class = 1 THEN 1 ELSE 0 END) AS GoldBadge,
    MAX(CASE WHEN bh.Class = 2 THEN 1 ELSE 0 END) AS SilverBadge,
    MAX(CASE WHEN bh.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadge,
    bh.Date AS BadgeDate,
    p.CreationDate AS CreatedAt
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
LEFT JOIN 
    Badges bh ON u.Id = bh.UserId
LEFT JOIN 
    (SELECT DISTINCT PostId FROM PostHistory PH WHERE PH.PostHistoryTypeId IN (10, 11)) PHFiltered ON p.Id = PHFiltered.PostId 
WHERE 
    p.CreationDate BETWEEN '2022-01-01' AND '2023-10-01'
GROUP BY 
    u.DisplayName, u.Reputation, p.Title, bh.Date, p.CreationDate
HAVING 
    COUNT(c.Id) > 5 
ORDER BY 
    u.Reputation DESC, CommentCount DESC;
