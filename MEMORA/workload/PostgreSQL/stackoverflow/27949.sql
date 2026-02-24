
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Body,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Location,
        (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = u.Id AND PostTypeId = 1) AS QuestionCount,
        (SELECT COUNT(*) FROM Badges WHERE UserId = u.Id) AS BadgeCount
    FROM 
        Users u
), RecentPostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'  
    GROUP BY 
        p.Id, p.OwnerUserId
), CombinedResults AS (
    SELECT 
        ur.DisplayName,
        ur.Reputation,
        ur.Location,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rpa.CommentCount,
        rpa.VoteCount,
        ur.QuestionCount,
        ur.BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    JOIN 
        RecentPostActivity rpa ON rp.PostId = rpa.PostId
    WHERE 
        rp.RN = 1  
)
SELECT 
    DisplayName,
    Reputation,
    Location,
    Title,
    CreationDate,
    ViewCount,
    Score,
    CommentCount,
    VoteCount,
    QuestionCount,
    BadgeCount
FROM 
    CombinedResults
ORDER BY 
    Reputation DESC, ViewCount DESC
LIMIT 10;
