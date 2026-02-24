
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.Reputation AS OwnerReputation,
        COUNT(a.Id) AS AnswerCount,
        RANK() OVER (PARTITION BY p.Id ORDER BY u.Reputation DESC) AS RankByReputation,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.ViewCount DESC) AS RowByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, u.Reputation
), FilteredPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        ViewCount, 
        OwnerReputation,
        AnswerCount 
    FROM 
        RankedPosts
    WHERE 
        RankByReputation = 1 AND RowByViews = 1  
), TopBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    JOIN 
        FilteredPosts fp ON b.UserId = fp.OwnerReputation
    GROUP BY 
        b.UserId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.OwnerReputation,
    fp.AnswerCount,
    tb.BadgeNames
FROM 
    FilteredPosts fp
LEFT JOIN 
    TopBadges tb ON fp.OwnerReputation = tb.UserId
WHERE 
    fp.ViewCount > 100
ORDER BY 
    fp.ViewCount DESC, fp.CreationDate DESC;
