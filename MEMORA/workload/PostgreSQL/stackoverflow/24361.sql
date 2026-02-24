WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - interval '1 year'
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.CreationDate
),
RecentPostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ',') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, '><')) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - interval '30 days'
    GROUP BY 
        p.Id
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)

SELECT 
    rp.Id,
    rp.Title,
    rp.CommentCount,
    COALESCE(pv.UpVotes, 0) AS UpVotes,
    COALESCE(pv.DownVotes, 0) AS DownVotes,
    plt.Tags,
    CASE 
        WHEN rp.CommentCount > 50 THEN 'Hot Post'
        WHEN rp.CommentCount = 0 AND pv.UpVotes > pv.DownVotes THEN 'Potentially Viral'
        ELSE 'Normal Activity'
    END AS ActivityStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVotes pv ON rp.Id = pv.PostId
LEFT JOIN 
    RecentPostTags plt ON rp.Id = plt.PostId
WHERE 
    (rp.PostTypeId = 1 AND rp.rn <= 5) OR (rp.PostTypeId = 2 AND rp.CommentCount > 10)
ORDER BY 
    rp.CreationDate DESC, rp.CommentCount DESC
LIMIT 100;