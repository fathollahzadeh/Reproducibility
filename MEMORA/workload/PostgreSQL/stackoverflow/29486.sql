WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        t.TagName,
        COUNT(t.TagName) AS TagCount
    FROM 
        Posts p
    JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName) ON p.Id = p.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, t.TagName
),
PostVoteStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        pc.TagName,
        COALESCE(pvs.UpVotes, 0) AS UpVotes,
        COALESCE(pvs.DownVotes, 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        PostTagCounts pc ON p.Id = pc.PostId
    LEFT JOIN 
        PostVoteStats pvs ON p.Id = pvs.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, pc.TagName, pvs.UpVotes, pvs.DownVotes
),
PopularPosts AS (
    SELECT 
        pa.*,
        ROW_NUMBER() OVER (PARTITION BY pa.TagName ORDER BY pa.UpVotes DESC, pa.Score DESC) AS Rank
    FROM 
        PostActivity pa
)
SELECT 
    PostId,
    Title,
    TagName,
    UpVotes,
    DownVotes,
    CommentCount,
    RANK() OVER (ORDER BY UpVotes DESC) AS TotalRank
FROM 
    PopularPosts
WHERE 
    Rank <= 5
ORDER BY 
    TagName, UpVotes DESC;
