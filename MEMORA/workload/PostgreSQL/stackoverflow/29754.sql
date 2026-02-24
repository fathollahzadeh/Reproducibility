
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        MAX(ph.CreationDate) AS LastEditDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC, COUNT(DISTINCT a.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CommentCount,
        rp.AnswerCount,
        rp.LastEditDate,
        rp.Rank
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    fp.Title,
    fp.Body,
    fp.Tags,
    fp.CommentCount,
    fp.AnswerCount,
    fp.LastEditDate,
    ur.DisplayName AS UserDisplayName,
    ur.Reputation,
    ur.BadgeCount
FROM 
    FilteredPosts fp
JOIN 
    Users u ON fp.PostId = u.Id
JOIN 
    UserReputation ur ON u.Id = ur.UserId
ORDER BY 
    fp.LastEditDate DESC, fp.CommentCount DESC;
