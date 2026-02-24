WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentsCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'
    GROUP BY 
        p.Id, u.DisplayName
),

FilteredPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Tags,
        RP.CreationDate,
        RP.Author,
        RP.CommentsCount,
        RP.Upvotes,
        RP.Downvotes
    FROM 
        RankedPosts RP
    WHERE 
        RP.Rank <= 5  
)

SELECT 
    FP.PostId,
    FP.Title,
    FP.Author,
    FP.CreationDate,
    FP.CommentsCount,
    FP.Upvotes,
    FP.Downvotes,
    ARRAY_LENGTH(string_to_array(FP.Tags, ','), 1) AS TagCount,  
    CASE WHEN FP.Upvotes - FP.Downvotes > 0 THEN 'Positive' ELSE 'Negative' END AS VoteSentiment
FROM 
    FilteredPosts FP
ORDER BY 
    FP.Upvotes DESC, 
    FP.CreationDate DESC;