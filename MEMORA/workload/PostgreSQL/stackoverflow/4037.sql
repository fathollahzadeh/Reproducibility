WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Score,
        rv.UpVotes,
        rv.DownVotes,
        CASE 
            WHEN rv.UpVotes > rv.DownVotes THEN 'Positive'
            WHEN rv.UpVotes < rv.DownVotes THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteSentiment
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
    WHERE 
        rp.PostRank <= 5
)
SELECT 
    ps.*,
    CASE 
        WHEN ps.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN 'Older'
        ELSE 'Recent'
    END AS PostAge,
    ARRAY_LENGTH(string_to_array(ps.Title, ' '), 1) AS TitleWordCount
FROM 
    PostStats ps
WHERE 
    ps.Score IS NOT NULL
ORDER BY 
    ps.Score DESC, 
    ps.CreationDate DESC;