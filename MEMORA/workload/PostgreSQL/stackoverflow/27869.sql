
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Tags, p.ViewCount
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.ViewCount,
        rp.CommentCount,
        rp.AnswerCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.Rank,
        (rp.UpVotes - rp.DownVotes) AS NetVotes,
        ARRAY_AGG(DISTINCT t.TagName) AS AllTags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Posts p ON rp.PostId = p.Id
    LEFT JOIN 
        Tags t ON t.TagName = ANY(string_to_array(rp.Tags, '>'))
    WHERE 
        rp.ViewCount > 100  
    GROUP BY 
        rp.PostId, rp.Title, rp.Tags, rp.ViewCount, rp.CommentCount, rp.AnswerCount, rp.UpVotes, rp.DownVotes, rp.Rank
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.ViewCount,
    fp.CommentCount,
    fp.AnswerCount,
    fp.NetVotes,
    fp.AllTags,
    CASE 
        WHEN fp.Rank <= 10 THEN 'Top 10'
        WHEN fp.Rank <= 50 THEN 'Top 11 to 50'
        ELSE 'Below 50'
    END AS RankCategory
FROM 
    FilteredPosts fp
ORDER BY 
    fp.NetVotes DESC, fp.ViewCount DESC, fp.Rank;
