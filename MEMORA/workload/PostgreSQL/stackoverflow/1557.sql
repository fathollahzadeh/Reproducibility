WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.ViewCount,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
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
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.ViewCount,
        pv.UpVotes,
        pv.DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVotes pv ON rp.Id = pv.PostId
    WHERE 
        rp.PostRank = 1
)
SELECT 
    t.TagName,
    COUNT(DISTINCT tp.Id) AS PostCount,
    COALESCE(SUM(tp.UpVotes - tp.DownVotes), 0) AS NetVotes,
    AVG(tp.ViewCount) AS AvgViewCount
FROM 
    Tags t
JOIN 
    Posts p ON p.Tags ILIKE '%' || t.TagName || '%'
JOIN 
    TopPosts tp ON tp.Id = p.Id
GROUP BY 
    t.TagName
HAVING 
    COUNT(DISTINCT tp.Id) > 5
ORDER BY 
    NetVotes DESC NULLS LAST;