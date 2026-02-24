
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10
),
PostAggregate AS (
    SELECT 
        p.PostId,
        p.Title,
        p.OwnerDisplayName,
        SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN pt.Name = 'Question' THEN 1 ELSE 0 END) AS QuestionCount,
        AVG(v.BountyAmount) AS AverageBounty
    FROM 
        TopPosts p
    LEFT JOIN 
        Posts ans ON p.PostId = ans.ParentId
    LEFT JOIN 
        PostTypes pt ON ans.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.PostId = v.PostId AND v.VoteTypeId = 8 
    GROUP BY 
        p.PostId, p.Title, p.OwnerDisplayName
)
SELECT 
    pa.Title,
    pa.OwnerDisplayName,
    pa.AnswerCount,
    pa.QuestionCount,
    pa.AverageBounty
FROM 
    PostAggregate pa
ORDER BY 
    pa.AnswerCount DESC, pa.QuestionCount DESC;
