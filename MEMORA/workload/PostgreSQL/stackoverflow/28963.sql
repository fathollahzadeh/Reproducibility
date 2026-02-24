WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank,
        COUNT(a.Id) OVER (PARTITION BY p.Tags) AS TotalAnswers
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.TotalAnswers
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank = 1 
),
PostWithUserDetails AS (
    SELECT 
        trp.PostId,
        trp.Title,
        trp.Tags,
        trp.CreationDate,
        trp.Score,
        trp.ViewCount,
        trp.AnswerCount,
        u.Id AS UserId,
        u.DisplayName AS UserName,
        u.Reputation AS UserReputation
    FROM 
        TopRankedPosts trp
    JOIN 
        Users u ON trp.PostId = u.Id
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.Tags,
    p.UserId,
    p.UserName,
    p.UserReputation,
    COALESCE(SUM(co.Score), 0) AS TotalComments,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
FROM 
    PostWithUserDetails p
LEFT JOIN 
    Comments co ON p.PostId = co.PostId
LEFT JOIN 
    Votes v ON p.PostId = v.PostId AND v.VoteTypeId IN (8, 9) 
GROUP BY 
    p.PostId, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.Tags, p.UserId, p.UserName, p.UserReputation
ORDER BY 
    p.Score DESC, p.ViewCount DESC;