
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.ViewCount, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Tags,
        CreationDate,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        AnswerCount
    FROM 
        RankedPosts
    WHERE 
        ViewRank <= 10
),
TagsStats AS (
    SELECT 
        UNNEST(string_to_array(Tags, '>')) AS TagName, 
        COUNT(*) AS PostCount
    FROM 
        TopPosts
    GROUP BY 
        TagName
),
BadgesStats AS (
    SELECT 
        U.Id AS UserId, 
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges b ON U.Id = b.UserId
    GROUP BY 
        U.Id
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.CommentCount,
    tp.AnswerCount,
    ts.TagName,
    bs.UserId,
    bs.GoldBadges,
    bs.SilverBadges,
    bs.BronzeBadges
FROM 
    TopPosts tp
LEFT JOIN 
    TagsStats ts ON tp.Tags LIKE CONCAT('%>', ts.TagName, '>%') 
LEFT JOIN 
    BadgesStats bs ON tp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = bs.UserId)
ORDER BY 
    tp.ViewCount DESC, 
    ts.PostCount DESC;
