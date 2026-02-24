
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'), 1) AS TagCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE((SELECT COUNT(*)
                  FROM Votes v
                  WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE((SELECT COUNT(*)
                  FROM Votes v
                  WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVotes
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName, u.Reputation
),
FilteredPosts AS (
    SELECT 
        *,
        (UpVotes - DownVotes) AS NetVotes,
        (Reputation / NULLIF(TagCount, 0)) AS ReputationPerTag
    FROM 
        RecentPosts
    WHERE 
        TagCount > 0
),
RankedPosts AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY NetVotes DESC, CreationDate DESC) AS Rank
    FROM 
        FilteredPosts
)
SELECT 
    PostId,
    Title,
    Body,
    OwnerDisplayName,
    CreationDate,
    TagCount,
    UpVotes,
    DownVotes,
    NetVotes,
    Reputation,
    ReputationPerTag,
    Rank
FROM 
    RankedPosts
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
