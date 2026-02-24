
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS UserDisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Tags, p.CreationDate, u.Reputation
),
TagStatistics AS (
    SELECT 
        Tags,
        COUNT(PostId) AS TotalPosts,
        SUM(CommentCount) AS TotalComments,
        SUM(UpVoteCount) AS TotalUpVotes,
        SUM(DownVoteCount) AS TotalDownVotes
    FROM 
        RankedPosts
    GROUP BY 
        Tags
),
TopTags AS (
    SELECT 
        Tags,
        TotalPosts,
        TotalComments,
        TotalUpVotes,
        TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT 
    tt.Tags,
    tt.TotalPosts,
    tt.TotalComments,
    tt.TotalUpVotes,
    tt.TotalDownVotes,
    CASE 
        WHEN tt.TotalPosts > 50 THEN 'Very Active'
        WHEN tt.TotalPosts > 20 THEN 'Active'
        ELSE 'Less Active'
    END AS ActivityLevel
FROM 
    TopTags tt
WHERE 
    tt.TagRank <= 10 
ORDER BY 
    tt.TotalPosts DESC;
