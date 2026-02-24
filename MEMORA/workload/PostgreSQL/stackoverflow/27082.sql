WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2 
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, u.Reputation
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.OwnerReputation,
        rp.AnswerCount,
        rp.UpVotes,
        rp.DownVotes,
        (rp.UpVotes - rp.DownVotes) AS VoteScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 
),
RatedPosts AS (
    SELECT 
        fp.*,
        CASE 
            WHEN fp.UpVotes >= 10 THEN 'Hot'
            WHEN fp.VoteScore > 0 THEN 'Popular'
            ELSE 'Normal'
        END AS PostStatus
    FROM 
        FilteredPosts fp
)
SELECT 
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    rp.Title,
    rp.PostStatus,
    rp.CreationDate,
    rp.AnswerCount
FROM 
    RatedPosts rp
WHERE 
    rp.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' 
ORDER BY 
    rp.VoteScore DESC, 
    rp.CreationDate DESC
LIMIT 50;