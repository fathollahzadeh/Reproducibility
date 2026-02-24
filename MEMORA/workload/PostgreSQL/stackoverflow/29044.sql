
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TopQuestions AS (
    SELECT 
        PostId,
        Title,
        OwnerUserId,
        OwnerDisplayName,
        CreationDate,
        LastActivityDate,
        ViewCount,
        AnswerCount,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        ViewRank <= 10
),
UserReputation AS (
    SELECT 
        id AS UserId,
        Reputation,
        DisplayName
    FROM 
        Users
    WHERE 
        Reputation > 1000 
),
QuestionComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    tq.Title,
    tq.OwnerDisplayName,
    tq.ViewCount,
    tq.AnswerCount,
    tq.CommentCount,
    COALESCE(ur.Reputation, 0) AS OwnerReputation,
    COALESCE(cb.CommentCount, 0) AS TotalComments,
    COALESCE(pb.BadgeCount, 0) AS TotalBadges
FROM 
    TopQuestions tq
LEFT JOIN 
    UserReputation ur ON tq.OwnerUserId = ur.UserId
LEFT JOIN 
    QuestionComments cb ON tq.PostId = cb.PostId
LEFT JOIN 
    PostBadges pb ON tq.OwnerUserId = pb.UserId
ORDER BY 
    tq.ViewCount DESC, tq.AnswerCount DESC;
