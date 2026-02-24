
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        pt.Name AS PostType
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserID,
        u.Reputation,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
TopUsers AS (
    SELECT 
        ur.UserID,
        ur.DisplayName,
        ur.Reputation,
        ur.PostCount,
        ur.TotalScore,
        ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC) AS UserRank
    FROM 
        UserReputation ur
    WHERE 
        ur.PostCount > 10
)
SELECT 
    rp.PostID,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    top.DisplayName AS OwnerName,
    top.Reputation AS OwnerReputation,
    rp.PostType
FROM 
    RankedPosts rp
JOIN 
    TopUsers top ON rp.OwnerUserId = top.UserID
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.PostType, rp.Score DESC;
