WITH UserVoteDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN vt.Name = 'BountyStart' THEN v.BountyAmount ELSE 0 END) AS TotalBounty,
        DENSE_RANK() OVER (ORDER BY COUNT(v.Id) DESC) AS VoteRank
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT UserId, DisplayName, TotalVotes, UpVotes, DownVotes, TotalBounty
    FROM UserVoteDetails
    WHERE VoteRank <= 10
),
PostWithComments AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstChangeDate,
        COUNT(CASE WHEN pht.Name IN ('Initial Title', 'Edit Title') THEN 1 END) AS TitleEdits,
        COUNT(CASE WHEN pht.Name IN ('Initial Body', 'Edit Body') THEN 1 END) AS BodyEdits,
        COUNT(CASE WHEN pht.Name IN ('Initial Tags', 'Edit Tags') THEN 1 END) AS TagEdits
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName AS UserDisplayName,
    u.TotalVotes,
    u.UpVotes,
    u.DownVotes,
    u.TotalBounty,
    pwd.PostId,
    pwd.Title AS PostTitle,
    pwd.CreationDate AS PostCreationDate,
    pwd.CommentCount,
    pwd.TotalCommentScore,
    phd.FirstChangeDate,
    phd.TitleEdits,
    phd.BodyEdits,
    phd.TagEdits
FROM 
    TopUsers u
JOIN 
    PostWithComments pwd ON u.UserId = pwd.PostId 
LEFT JOIN 
    PostHistoryDetails phd ON pwd.PostId = phd.PostId
WHERE 
    (pwd.CommentCount > 0 OR phd.TitleEdits > 0)
ORDER BY 
    u.TotalVotes DESC, pwd.TotalCommentScore DESC
LIMIT 50;