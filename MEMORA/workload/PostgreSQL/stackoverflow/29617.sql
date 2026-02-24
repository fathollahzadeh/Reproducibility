WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1          
    LEFT JOIN 
        Comments c ON p.Id = c.PostId                               
    LEFT JOIN 
        Votes v ON p.Id = v.PostId                                  
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id                             
    WHERE 
        p.PostTypeId = 1                                           
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId, u.DisplayName
),
FilteredPosts AS (
    SELECT
        rp.PostID,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.AnswerCount,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RecentPostRank <= 5                                    
),
PostTags AS (
    SELECT
        p.Id AS PostID,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM
        Posts p
    JOIN
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag_name ON true
    JOIN
        Tags t ON t.TagName = tag_name
    GROUP BY
        p.Id
)
SELECT 
    fp.PostID,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.AnswerCount,
    fp.CommentCount,
    fp.VoteCount,
    pt.Tags
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostTags pt ON fp.PostID = pt.PostID
ORDER BY 
    fp.CreationDate DESC;