WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        q.OwnerDisplayName AS QuestionOwner,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.Id ORDER BY COUNT(DISTINCT v.Id) DESC) AS RankByVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Posts q ON p.ParentId = q.Id
    WHERE 
        p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id, p.Title, p.Body, q.OwnerDisplayName, p.CreationDate
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CommentCount,
        VoteCount,
        QuestionOwner,
        CreationDate
    FROM 
        RankedPosts
    WHERE 
        RankByVotes = 1
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tp.PostId,
    tp.Title AS PostTitle,
    tp.Body AS PostBody,
    tp.CommentCount,
    tp.VoteCount,
    tp.QuestionOwner,
    tp.CreationDate,
    us.UserId,
    us.DisplayName AS OwnerDisplayName,
    us.QuestionCount,
    us.AnswerCount,
    us.TotalBounty
FROM 
    TopPosts tp
JOIN 
    UserStats us ON tp.QuestionOwner = us.DisplayName
ORDER BY 
    tp.VoteCount DESC, tp.CommentCount DESC;