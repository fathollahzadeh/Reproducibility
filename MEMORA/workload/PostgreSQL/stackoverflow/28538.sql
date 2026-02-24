WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'), 1) AS TagCount,
        p.CreationDate,
        p.LastActivityDate,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.Reputation > 1000 THEN 'Experienced'
            WHEN rp.Reputation BETWEEN 100 AND 1000 THEN 'Moderate'
            ELSE 'Novice'
        END AS UserExperience
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagCount > 3  
),
PostInsights AS (
    SELECT 
        p.PostId,
        p.Title,
        p.UserExperience,
        COUNT(c.Id) AS CommentCount,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        FilteredPosts p
    LEFT JOIN 
        Comments c ON p.PostId = c.PostId
    LEFT JOIN 
        Votes v ON p.PostId = v.PostId
    GROUP BY 
        p.PostId, p.Title, p.UserExperience
),
RecentInsights AS (
    SELECT 
        PostId,
        Title,
        UserExperience,
        CommentCount,
        LastVoteDate,
        ROW_NUMBER() OVER (ORDER BY LastVoteDate DESC) AS RecentRank
    FROM 
        PostInsights
)
SELECT 
    ri.PostId,
    ri.Title,
    ri.UserExperience,
    ri.CommentCount,
    ri.LastVoteDate
FROM 
    RecentInsights ri
WHERE 
    ri.RecentRank <= 10  
ORDER BY 
    ri.LastVoteDate DESC;