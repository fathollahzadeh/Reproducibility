WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COUNT(*) OVER (PARTITION BY p.PostTypeId) AS TotalPosts
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(p.Tags, '><')) AS TagName
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEdit
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        ph.PostId
),
PostsSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        pt.TagName,
        pv.UpVotes,
        pv.DownVotes,
        re.EditCount,
        re.LastEdit,
        rp.Rank,
        rp.TotalPosts
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostTags pt ON rp.PostId = pt.PostId
    LEFT JOIN 
        PostVotes pv ON rp.PostId = pv.PostId
    LEFT JOIN 
        RecentEdits re ON rp.PostId = re.PostId
    WHERE 
        rp.Rank <= 5  
)
SELECT DISTINCT
    ps.PostId,
    ps.Title,
    ps.Author,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.TagName,
    COALESCE(ps.UpVotes, 0) AS UpVotes,
    COALESCE(ps.DownVotes, 0) AS DownVotes,
    COALESCE(ps.EditCount, 0) AS EditCount,
    ps.LastEdit,
    ps.Rank,
    ps.TotalPosts
FROM 
    PostsSummary ps
ORDER BY 
    ps.CreationDate DESC, ps.Score DESC;