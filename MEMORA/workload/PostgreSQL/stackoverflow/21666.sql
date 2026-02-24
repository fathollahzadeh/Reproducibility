WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByViews <= 5
),
PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes,
        SUM(COALESCE(b.Class, 0)) AS BadgeCount
    FROM 
        Votes v
    INNER JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    LEFT JOIN 
        Badges b ON v.UserId = b.UserId
    GROUP BY 
        v.PostId
)
SELECT 
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    COALESCE(pv.UpVotes, 0) AS UpVotes,
    COALESCE(pv.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN pv.UpVotes > pv.DownVotes THEN 'Positive'
        WHEN pv.UpVotes < pv.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = fp.PostId AND v.UserId = 1) THEN 'User Has Voted'
        ELSE 'User Has Not Voted'
    END AS UserVoteStatus
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostVotes pv ON fp.PostId = pv.PostId
ORDER BY 
    fp.ViewCount DESC, fp.Score DESC
FETCH FIRST 10 ROWS ONLY;