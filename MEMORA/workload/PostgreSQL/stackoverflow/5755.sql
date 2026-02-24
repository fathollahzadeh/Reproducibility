WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.AnswerCount,
        COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.ViewCount > 100
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.AnswerCount,
        rp.OwnerDisplayName,
        pv.VoteCount,
        pv.UpVotes,
        pv.DownVotes
    FROM 
        RankedPosts rp
    JOIN 
        PostVotes pv ON rp.PostId = pv.PostId
    WHERE 
        rp.Rank <= 10
)
SELECT 
    pp.Title,
    pp.OwnerDisplayName,
    pp.ViewCount,
    pp.AnswerCount,
    pp.VoteCount,
    pp.UpVotes,
    pp.DownVotes,
    EXTRACT(YEAR FROM pp.CreationDate) AS PostYear
FROM 
    PopularPosts pp
ORDER BY 
    pp.ViewCount DESC,
    pp.AnswerCount DESC;