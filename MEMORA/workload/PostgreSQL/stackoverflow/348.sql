
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName, 
        u.Reputation, 
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount, 
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount, 
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty 
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        QuestionCount, 
        AnswerCount,
        TotalBounty,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, QuestionCount DESC) AS Rank 
    FROM 
        UserStats 
), 
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        COALESCE(pc.CommentCount, 0) AS CommentCount, 
        COALESCE(ph.EditCount, 0) AS EditCount,
        p.OwnerUserId
    FROM 
        Posts p 
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) pc ON p.Id = pc.PostId 
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS EditCount 
        FROM 
            PostHistory 
        WHERE 
            PostHistoryTypeId IN (4, 5, 6) 
        GROUP BY 
            PostId
    ) ph ON p.Id = ph.PostId
)
SELECT 
    u.UserId, 
    u.DisplayName, 
    u.Reputation, 
    p.Title, 
    p.CreationDate, 
    p.Score, 
    p.ViewCount, 
    p.CommentCount, 
    p.EditCount 
FROM 
    TopUsers u 
JOIN 
    PostActivity p ON u.UserId = p.OwnerUserId 
WHERE 
    u.Rank <= 10 
ORDER BY 
    u.Reputation DESC, 
    p.Score DESC;
