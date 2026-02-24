
WITH ProcessedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Tags,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) DESC) AS PopularityRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Tags
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Tags,
        Upvotes,
        Downvotes,
        CommentCount,
        PopularityRank
    FROM 
        ProcessedPosts
    WHERE 
        (Tags LIKE '%SQL%' OR Tags LIKE '%Database%') 
        AND CreationDate >= CURRENT_DATE - INTERVAL '1 year'  
        AND Upvotes > 5  
),
RankedPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Tags,
        Upvotes,
        Downvotes,
        CommentCount,
        PopularityRank,
        ROW_NUMBER() OVER (ORDER BY PopularityRank) AS Rank
    FROM 
        FilteredPosts
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Tags,
    rp.Upvotes,
    rp.Downvotes,
    rp.CommentCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    pht.Name AS PostHistoryTypeName
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.PostId = u.Id
JOIN 
    PostHistory ph ON rp.PostId = ph.PostId
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    rp.PopularityRank <= 10  
ORDER BY 
    rp.PopularityRank;
